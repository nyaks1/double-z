use anchor_lang::prelude::*;
use anchor_lang::system_program;

declare_id!("HzWH4JBt9HZCf6AmkN9rD1XEH6YBDosumb23rrMRhscu"); 

#[program]
pub mod doublezero {
    use super::*;

    // 1. Create the Escrow (The Lock)
    pub fn create_escrow(ctx: Context<CreateEscrow>, amount: u64, _timestamp: i64) -> Result<()> {
        let escrow_state = &mut ctx.accounts.escrow_state;
        
        escrow_state.sender = ctx.accounts.sender.key();
        escrow_state.recipient = ctx.accounts.recipient.key();
        escrow_state.amount = amount;
        escrow_state.bump = ctx.bumps.escrow_state;

        // Move SOL from Sender to PDA
        let cpi_context = CpiContext::new(
            ctx.accounts.system_program.to_account_info(),
            system_program::Transfer {
                from: ctx.accounts.sender.to_account_info(),
                to: ctx.accounts.escrow_state.to_account_info(),
            },
        );
        system_program::transfer(cpi_context, amount)?;

        msg!("Escrow created! Vault locked with {} lamports.", amount);
        Ok(())
    }

    // 2. Release the Funds (The Key)
    pub fn release_funds(ctx: Context<ReleaseFunds>, _timestamp: i64) -> Result<()> {
        let amount = ctx.accounts.escrow_state.amount;

        // Move SOL from PDA to Recipient
        **ctx.accounts.escrow_state.to_account_info().try_borrow_mut_lamports()? -= amount;
        **ctx.accounts.recipient.to_account_info().try_borrow_mut_lamports()? += amount;

        msg!("Funds released! {} lamports sent to the recipient.", amount);
        Ok(())
    }
}

#[derive(Accounts)]
#[instruction(amount: u64, timestamp: i64)]
pub struct CreateEscrow<'info> {
    #[account(mut)]
    pub sender: Signer<'info>,
    /// CHECK: Recipient pubkey stored in state.
    pub recipient: AccountInfo<'info>,
    #[account(
        init,
        payer = sender,
        space = 8 + 32 + 32 + 8 + 1,
        seeds = [b"escrow", sender.key().as_ref(), timestamp.to_le_bytes().as_ref()],
        bump
    )]
    pub escrow_state: Account<'info, EscrowState>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(timestamp: i64)]
pub struct ReleaseFunds<'info> {
    #[account(mut)]
    pub recipient: Signer<'info>,
    #[account(mut)]
    pub sender: AccountInfo<'info>,
    #[account(
        mut,
        has_one = recipient,
        has_one = sender,
        close = sender, // Returns rent to sender
        seeds = [b"escrow", sender.key().as_ref(), timestamp.to_le_bytes().as_ref()],
        bump = escrow_state.bump
    )]
    pub escrow_state: Account<'info, EscrowState>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct EscrowState {
    pub sender: Pubkey,
    pub recipient: Pubkey,
    pub amount: u64,
    pub bump: u8,
}
